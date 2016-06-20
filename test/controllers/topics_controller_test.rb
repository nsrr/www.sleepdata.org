# frozen_string_literal: true

require 'test_helper'

# Tests to assure that users can view and modify topics.
class TopicsControllerTest < ActionController::TestCase
  setup do
    @topic = topics(:one)
    @admin = users(:admin)
  end

  def topic_params
    {
      title: 'New Topic Title',
      slug: 'new-topic-title',
      description: 'First Reply on New Topic',
      tag_ids: [ActiveRecord::FixtureSet.identify(:meeting)]
    }
  end

  test 'should get markup' do
    get :markup
    assert_response :success
  end

  test 'should subscribe to notifications' do
    login(users(:valid))
    post :subscription, params: { id: @topic, notify: '1' }, format: 'js'
    assert_not_nil assigns(:topic)
    assert_equal true, assigns(:topic).subscribed?(users(:valid))
    assert_template 'subscription'
    assert_response :success
  end

  test 'should unsubscribe from notifications' do
    login(users(:valid))
    post :subscription, params: { id: @topic, notify: '0' }, format: 'js'
    assert_not_nil assigns(:topic)
    assert_equal false, assigns(:topic).subscribed?(users(:valid))
    assert_template 'subscription'
    assert_response :success
  end

  test 'should not subscribe for anonymous user' do
    post :subscription, params: { id: @topic, notify: '1' }, format: 'js'
    assert_nil assigns(:topic)
    assert_template nil
    assert_response :unauthorized
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:topics)
  end

  test 'should search index' do
    get :index, params: { s: 'variable' }
    assert_response :success
    assert_not_nil assigns(:topics)
  end

  test 'should get new' do
    login(users(:valid))
    get :new
    assert_response :success
  end

  test 'should create topic' do
    login(users(:valid))
    assert_difference('Reply.count') do
      assert_difference('Topic.count') do
        post :create, params: { topic: topic_params }
      end
    end
    assert_not_nil assigns(:topic)
    assert_equal 'New Topic Title', assigns(:topic).title
    assert_equal 'new-topic-title', assigns(:topic).slug
    assert_equal users(:valid), assigns(:topic).user
    assert_equal 'First Reply on New Topic', assigns(:topic).replies.first.description
    assert_equal users(:valid), assigns(:topic).replies.first.user
    assert_not_nil assigns(:topic).last_reply_at
    assert_equal [], assigns(:topic).tags
    assert_equal true, assigns(:topic).subscribed?(users(:valid))
    assert_redirected_to topic_path(assigns(:topic))
  end

  test 'should create topic with tags as core member' do
    login(users(:core))
    assert_difference('Topic.count') do
      post :create, params: { topic: topic_params }
    end
    assert_not_nil assigns(:topic)
    assert_equal [tags(:meeting)], assigns(:topic).tags
    assert_redirected_to topic_path(assigns(:topic))
  end

  test 'should create topic with tags as AUG member' do
    login(users(:aug))
    assert_difference('Topic.count') do
      post :create, params: { topic: topic_params }
    end
    assert_not_nil assigns(:topic)
    assert_equal [tags(:meeting)], assigns(:topic).tags
    assert_redirected_to topic_path(assigns(:topic))
  end

  test 'should not create topic with blank description' do
    login(users(:valid))
    assert_difference('Reply.count', 0) do
      assert_difference('Topic.count', 0) do
        post :create, params: { topic: topic_params.merge(description: '') }
      end
    end
    assert_not_nil assigns(:topic)
    assert assigns(:topic).errors.size > 0
    assert_equal ["can't be blank"], assigns(:topic).errors[:description]
    assert_template 'new'
    assert_response :success
  end

  # TODO: Decide on whether or not to remove this restriction.
  test 'should not create topic when user exceeds two topics per day' do
    skip
    login(users(:valid))
    topic_one = users(:valid).topics.create(title: 'Topic One', slug: 'topic-one', description: 'First Topic of the Day')
    topic_two = users(:valid).topics.create(title: 'Topic Two', slug: 'topic-two', description: 'Second Topic of the Day')
    assert_difference('Reply.count', 0) do
      assert_difference('Topic.count', 0) do
        post :create, params: { topic: { title: 'Third topic of the day', slug: 'topic-three', description: 'Spamming Topics' } }
      end
    end
    assert_nil assigns(:topic)
    assert_equal 'You have exceeded your maximum topics created per day.', flash[:warning]
    assert_redirected_to topics_path
  end

  test 'should not create topic as banned user' do
    login(users(:banned))
    assert_difference('Reply.count', 0) do
      assert_difference('Topic.count', 0) do
        post :create, params: { topic: { name: 'I am trying to post a topic', slug: 'i-am-trying-to-post-a-topic', description: 'Visit my site with advertisements.' } }
      end
    end
    assert_nil assigns(:topic)
    assert_equal 'You do not have permission to post on the forum.', flash[:warning]
    assert_redirected_to topics_path
  end

  test 'should show topic' do
    get :show, params: { id: @topic }
    assert_response :success
  end

  test 'should not show topic from banned user' do
    get :show, params: { id: topics(:banned) }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should show topic to admin' do
    login(@admin)
    get :show, params: { id: @topic }
    assert_response :success
  end

  test 'should get edit' do
    login(users(:valid))
    get :edit, params: { id: @topic }
    assert_response :success
  end

  test 'should not get edit as another user' do
    login(users(:two))
    get :edit, params: { id: @topic }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should not get edit for locked topic' do
    login(users(:valid))
    get :edit, params: { id: topics(:locked) }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should not get edit for banned user' do
    login(users(:banned))
    get :edit, params: { id: topics(:banned) }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should update topic' do
    login(users(:valid))
    patch :update, params: { id: @topic, topic: topic_params.merge(title: 'Updated Topic Title') }
    assert_not_nil assigns(:topic)
    assert_equal 'Updated Topic Title', assigns(:topic).title
    assert_redirected_to topic_path(assigns(:topic))
  end

  test 'should not update topic with blank title' do
    login(users(:valid))
    patch :update, params: { id: @topic, topic: topic_params.merge(title: '') }
    assert_template 'edit'
    assert_response :success
  end

  test 'should not update topic as another user' do
    login(users(:two))
    patch :update, params: { id: @topic, topic: topic_params.merge(title: 'Updated Topic Title') }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should not update topic as banned user' do
    login(users(:banned))
    patch :update, params: { id: topics(:banned), topic: topic_params.merge(title: 'Updated Topic Title') }
    assert_nil assigns(:topic)
    assert_redirected_to topics_path
  end

  test 'should lock topic as a system admin' do
    login(users(:admin))
    post :admin, params: { id: @topic, topic: { locked: '1' } }
    assert_not_nil assigns(:topic)
    assert_equal true, assigns(:topic).locked
    assert_redirected_to topics_path
  end

  test 'should not lock topic as a regular user' do
    login(users(:valid))
    post :admin, params: { id: @topic, topic: { locked: '1' } }
    assert_nil assigns(:topic)
    assert_redirected_to root_path
  end

  test 'should not lock topic as an anonymous user' do
    post :admin, params: { id: @topic, topic: { locked: '1' } }
    assert_nil assigns(:topic)
    assert_redirected_to new_user_session_path
  end

  test 'should sticky a topic as a system admin' do
    login(users(:admin))
    post :admin, params: { id: @topic, topic: { pinned: '1' } }
    assert_not_nil assigns(:topic)
    assert_equal true, assigns(:topic).pinned?
    assert_redirected_to topics_path
  end

  test 'should not sticky a topic as a regular user' do
    login(users(:valid))
    post :admin, params: { id: @topic, topic: { pinned: '1' } }
    assert_nil assigns(:topic)
    assert_redirected_to root_path
  end

  test 'should not sticky topic as an anonymous user' do
    post :admin, params: { id: @topic, topic: { pinned: '1' } }
    assert_nil assigns(:topic)
    assert_redirected_to new_user_session_path
  end

  test 'should not destroy topic as user' do
    login(users(:valid))
    assert_difference('Topic.current.count', 0) do
      delete :destroy, params: { id: @topic }
    end
    assert_redirected_to root_path
  end

  test 'should destroy topic as admin' do
    login(users(:admin))
    assert_difference('Topic.current.count', -1) do
      delete :destroy, params: { id: @topic }
    end
    assert_redirected_to topics_path
  end
end
