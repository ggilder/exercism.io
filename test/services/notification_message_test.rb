require './test/app_helper'

require 'services/message'
require 'services/notification_message'
require 'mocha/setup'

class NotificationMessageTest < MiniTest::Unit::TestCase
  include DBCleaner

  attr_reader :alice, :bob, :submission

  def setup
    super
    @alice = User.create(username: 'alice', email: 'test@exercism.io')
    @bob = User.create(username: 'bob')

    Submission.create(language: 'ruby', slug: 'anagram', state: 'done', user: alice)
    Hack::UpdatesUserExercise.new(alice.id, 'ruby', 'anagram').update

    @submission = Submission.create(language: 'ruby', slug: 'word-count', state: 'pending', user: alice)
    Hack::UpdatesUserExercise.new(alice.id, 'ruby', 'word-count').update
    @submission.reload
  end

  def notification_message
    @notification_message ||= NotificationMessage.new(user: alice, intercept_emails: true)
  end

  def test_subject
    Notification.on(submission, to: alice, regarding: 'dogs')
    Notification.on(submission, to: alice, regarding: 'puppies')

    assert_equal 'You have 2 notifications', notification_message.subject
  end

  def test_doesnt_send_empty_email
    notification_message.stubs(:notifications).returns([])
    assert_equal false, notification_message.ship
  end

  def test_sends_email
    return if ENV['CI'] == '1'

    Notification.on(submission, to: alice, regarding: 'strawberries')
    Notification.on(submission, to: alice, regarding: 'bananas', created_at: 2.hours.ago)
    Notification.on(submission, to: alice, regarding: 'apples', created_at: 4.hours.ago)
    Notification.on(submission, to: alice, regarding: 'cherries', created_at: 6.hours.ago)
    Notification.on(submission, to: alice, regarding: 'guavas', created_at: 8.hours.ago)
    Notification.on(submission, to: alice, regarding: 'lilikoi', created_at: 10.hours.ago)
    Notification.on(submission, to: alice, regarding: 'watermelon', created_at: 12.hours.ago)
    Submission.create(language: 'javascript', slug: 'word-count', state: 'pending', user: bob)
    Submission.create(language: 'ruby', slug: 'anagram', state: 'pending', user: bob, created_at: 4.hours.ago)
    notification_message.ship

    # integration test, view in mailcatcher.
  end

end
