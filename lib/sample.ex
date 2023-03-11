# defmodule Sample do
#   defmacro __using__(opts) do
#     c = Keyword.get(opts, :c)

#     quote location: :keep do
#       case unquote(c) do
#         [duration: [max: max, min: _min]] ->
#           def my() do
#             IO.inspect(max)
#           end

#         _ ->
#           def my do
#             IO.inspect("not matched")
#           end
#       end
#     end

#     max = 3

#     quote do
#       def my() do
#         IO.inspect(test)
#       end
#     end
#     # |> Macro.expand(__ENV__)
#     |> Macro.prewalk(fn
#       {:test, [], Sample} ->
#         max

#       i ->
#         IO.inspect("-------------")
#         IO.inspect(i)
#         # :ok
#     end)
#     # |> IO.inspect()

#     # quote do
#     #   var!(max) + 10
#     #   |> IO.inspect()
#     # end
#     # |> Code.eval_quoted([max: 10])

#     # {:__block__, [], [x | ast]} |> IO.inspect()
#   end
# end

# defmodule SampleUse do
#   # use Sample, c: [duration: [max: {2, :GB}, min: {1, :KB}]]
# end

# defmodule Foo do
#   defmacro foo(exp) do
#     quote do
#       doubled = unquote(exp) * 2
#       doubled
#     end
#   end
# end
