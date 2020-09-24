require_relative 'test_helper'

class GraphQL::Batch::CustomExecutorTest < Minitest::Test
  class MyCustomExecutor < GraphQL::Batch::Executor
    class << self
      attr_accessor :call_count
    end
    self.call_count = 0

    def around_promise_callbacks
      self.class.call_count += 1

      super
    end
  end

  class CustomDataloader < GraphQL::Dataloader
    class << self
      attr_accessor :call_count
    end
    self.call_count = 0
  end

  class Schema < GraphQL::Schema
    query ::QueryType
    mutation ::MutationType

    if TESTING_DATALOADER
      use GraphQL::Dataloader
    else
      use GraphQL::Batch, executor_class: MyCustomExecutor
    end
  end

  def setup
    MyCustomExecutor.call_count = 0
    CustomDataloader.call_count = 0
  end

  def in_batch
    if TESTING_DATALOADER
      GraphQL::Dataloader.load do
        yield
      end
    else
      GraphQL::Batch.batch(executor_class: MyCustomExecutor) do
        yield
      end
    end
  end

  def promise_call_count
    if TESTING_DATALOADER
      CustomDataloader.call_count
    else
      MyCustomExecutor.call_count
    end
  end

  def test_batch_accepts_custom_executor
    product = in_batch do
      RecordLoader.for(Product).load(1)
    end

    assert_equal 'Shirt', product.title
    assert promise_call_count > 0
  end

  def test_custom_executor_class
    query_string = '{ product(id: "1") { id } }'
    Schema.execute(query_string)

    assert promise_call_count > 0
  end
end
