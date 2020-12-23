require_relative 'test_helper'

class GraphQL::BatchTest < Minitest::Test
  def in_batch
    if TESTING_DATALOADER
      GraphQL::Dataloader.load { yield }
    else
      GraphQL::Batch.batch { yield }
    end
  end
  def test_batch
    product = in_batch do
      RecordLoader.for(Product).load(1)
    end
    assert_equal 'Shirt', product.title
  end

  def test_nested_batch
    promise1 = nil
    promise2 = nil

    product = in_batch do
      promise1 = RecordLoader.for(Product).load(1)
      in_batch do
        promise2 = RecordLoader.for(Product).load(1)
      end
      promise1
    end

    assert_equal 'Shirt', product.title
    assert_equal promise1, promise2
    assert_nil GraphQL::Batch::Executor.current
  end
end
