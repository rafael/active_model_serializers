require 'test_helper'

module ActiveModel
  class Serializer
    class NestedSerializersTest < Minitest::Test
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

        @serializer = PostPreviewSerializer.new(@post)
        @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
          @serializer,
          include: [:comments, :author]
        )
      end

#      def test_nested_serializer_first
#        hash = ActiveModel::SerializableResource.new(@post).serializable_hash
#        assert_equal(1, hash)
#      end
    end
  end
end
