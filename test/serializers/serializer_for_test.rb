require 'test_helper'

module ActiveModel
  class Serializer
    class SerializerForTest < Minitest::Test
      class ArraySerializerTest < Minitest::Test
        def setup
          @array = [1, 2, 3]
          @previous_array_serializer = ActiveModel::Serializer.config.array_serializer
        end

        def teardown
          ActiveModel::Serializer.config.array_serializer = @previous_array_serializer
        end

        def test_serializer_for_array
          serializer = ActiveModel::Serializer.serializer_for(@array)
          assert_equal ActiveModel::Serializer.config.array_serializer, serializer
        end

        def test_overwritten_serializer_for_array
          new_array_serializer = Class.new
          ActiveModel::Serializer.config.array_serializer = new_array_serializer
          serializer = ActiveModel::Serializer.serializer_for(@array)
          assert_equal new_array_serializer, serializer
        end
      end

      class SerializerTest < Minitest::Test
        class MyProfile < Profile
        end
        class CustomProfile
          def serializer_class; ProfileSerializer; end
        end

        def setup
          @post = Post.new(title: 'New Post', body: 'Body')
          @author = Author.new(name: 'Jane Blogger')
          @author.posts = [@post]
          @post.author = @author
          @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
          @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
          @post.comments = [@first_comment, @second_comment]
          @first_comment.post = @post
          @first_comment.author = @author
          @second_comment.post = @post
          @second_comment.author = nil
          @blog = Blog.new(id: 23, name: 'AMS Blog')
          @post.blog = @blog

          @profile = Profile.new
          @my_profile = MyProfile.new
          @custom_profile = CustomProfile.new
          @model = ::Model.new
        end

        def test_serializer_for_existing_serializer
          serializer = ActiveModel::Serializer.serializer_for(@profile)
          assert_equal ProfileSerializer, serializer
        end

        def test_serializer_for_not_existing_serializer
          serializer = ActiveModel::Serializer.serializer_for(@model)
          assert_equal nil, serializer
        end

        def test_serializer_inherited_serializer
          serializer = ActiveModel::Serializer.serializer_for(@my_profile)
          assert_equal ProfileSerializer, serializer
        end

        def test_serializer_custom_serializer
          serializer = ActiveModel::Serializer.serializer_for(@custom_profile)
          assert_equal ProfileSerializer, serializer
        end

        def test_serializer_nested_serializer
          serializer = PostSerializer.serializer_for(@first_comment)
          assert_equal(PostSerializer::CommentSerializer, serializer)
        end

        def test_serializer_toplevel_serializer
          serializer = ActiveModel::Serializer.serializer_for(@first_comment)
          assert_equal(CommentSerializer, serializer)
        end
      end
    end
  end
end
