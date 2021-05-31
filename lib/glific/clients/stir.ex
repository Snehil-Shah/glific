defmodule Glific.Clients.Stir do
  @moduledoc """
  Example implementation of survey computation for STiR
  Glific.Clients.Stir.compute_art_content(res)
  """

  @doc false
  @spec webhook(map) :: map()
  def webhook(%{results: results}),
    do: compute_survey_score(results)

  def webhook(_), do: %{}

  @doc false
  @spec blocked?(String.t()) :: boolean
  def blocked?(phone) do
    pattern = :binary.compile_pattern(["91", "1", "44", "256"])

    if String.starts_with?(phone, pattern),
      do: false,
      else: true
  end

  @spec get_value(String.t(), map()) :: integer()
  defp get_value(k, v) do
    k = String.downcase(k)

    input =
      if is_binary(v["input"]),
        do: String.downcase(v["input"]),
        else: ""

    if input == "y" do
      case k do
        "a1" -> 1
        "a2" -> 2
        "a3" -> 4
        "a4" -> 8
        "a5" -> 16
        _ -> 0
      end
    else
      0
    end
  end

  @spec get_art_content(String.t(), map()) :: String.t()
  defp get_art_content(k, v) do
    k = String.downcase(k)

    if(is_binary(v["input"]), do: String.downcase(v["input"]), else: "")
    |> process(k)
  end

  @spec process(String.t(), String.t()) :: String.t()
  defp process("n", "a1"), do: " *1*. More reflective discussion on the teaching strategy \n"
  defp process("n", "a2"), do: " *2*. Space for practicing a classroom strategy \n"
  defp process("n", "a3"), do: " *3*. Teachers get improvement focused feedback \n"
  defp process("n", "a4"), do: " *4*. Teachers participation \n"
  defp process("n", "a5"), do: " *5*. Developing concrete action plans \n"
  defp process("n", "a6"), do: " *6*. Teachers asking question \n"
  defp process(_, _), do: ""

  @doc """
  Return art content
  """
  @spec compute_art_content(map()) :: String.t()
  def compute_art_content(results) do
    results
    |> Enum.reduce(" ", fn {k, v}, acc ->
      "#{acc} #{get_art_content(k, v)}"
    end)
  end

  @doc """
  Return integer depending on number of n as response in messages
  """
  @spec compute_art_results(map()) :: non_neg_integer()
  def compute_art_results(results) do
    answers =
      results
      |> Enum.map(fn {_k, v} ->
        if is_binary(v["input"]),
          do: String.downcase(v["input"]),
          else: ""
      end)
      |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)

    cond do
      is_nil(Map.get(answers, "n")) -> 3
      Map.get(answers, "n") == 1 -> 1
      Map.get(answers, "n") > 1 -> 2
      true -> 3
    end
  end

  @doc """
  Return total score
  """
  @spec compute_survey_score(map()) :: map()
  def compute_survey_score(results) do
    results
    |> Enum.reduce(
      0,
      fn {k, v}, acc -> acc + get_value(k, v) end
    )
    |> get_content()
  end

  @spec get_content(integer()) :: map()
  defp get_content(score) do
    {status, content} =
      cond do
        rem(score, 7) == 0 -> {1, "Your score: #{score} is divisible by 7"}
        rem(score, 5) == 0 -> {2, "Your score: #{score} is divisible by 5"}
        rem(score, 3) == 0 -> {3, "Your score: #{score} is divisible by 3"}
        rem(score, 2) == 0 -> {4, "Your score: #{score} is divisible by 2"}
        true -> {5, "Your score: #{score} is not divisible by 2, 3, 5 or 7"}
      end

    %{
      status: to_string(status),
      content: content,
      score: to_string(score)
    }
  end
end
