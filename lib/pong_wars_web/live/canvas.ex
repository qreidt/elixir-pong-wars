defmodule PongWarsWeb.Canvas do
  use PongWarsWeb, :live_view

  @arena_size_x 528 # px
  @arena_size_y 528 # px
  @square_size 24
  @fps 45

  def mount(_params, _session, socket) do
    Process.send_after(self(), :update, 500)

    socket = update_socket(
      socket,
      create_arena(),
      %{ # player 1
        x: @arena_size_x / 4,
        y: @arena_size_y / 2,
        dx: 8, dy: 8
      },
      %{ # player 2
        x: (@arena_size_x / 4) * 3,
        y: @arena_size_y / 2,
        dx: -8, dy: -8
      }
    )

    {:ok, socket}
  end

  defp update_socket(socket, arena, player_1, player_2) do
    assign(socket, :arena, arena)
      |> assign(:player_1, player_1)
      |> assign(:player_2, player_2)
  end

  defp create_arena() do
    rows = ceil(@arena_size_x / @square_size)
    columns = ceil(@arena_size_y / @square_size)

    Enum.map(1..rows, fn x ->
      Enum.map(1..columns, fn _y ->
        if x < (rows / 2) + 1, do: :LIGHT, else: :DARK
      end)
    end)
  end

  def handle_info(:update, %{assigns: assigns} = socket) do
    %{arena: arena, player_1: player_1, player_2: player_2} = assigns

    {arena, player_1} = check_colisions(arena, player_1.x, player_1.y, player_1.dx, player_1.dy, :LIGHT)
    {arena, player_2} = check_colisions(arena, player_2.x, player_2.y, player_2.dx, player_2.dy, :DARK)

    {dx1, dy1} = check_boundary_collision(player_1.x, player_1.y, player_1.dx, player_1.dy)
    {dx2, dy2} = check_boundary_collision(player_2.x, player_2.y, player_2.dx, player_2.dy)

    player_1 = player_1
    |> Map.replace!(:x, player_1.x + dx1)
    |> Map.replace!(:y, player_1.y + dy1)
    |> Map.replace!(:dx, dx1)
    |> Map.replace!(:dy, dy1)

    player_2 = player_2
    |> Map.replace!(:x, player_2.x + dx2)
    |> Map.replace!(:y, player_2.y + dy2)
    |> Map.replace!(:dx, dx2)
    |> Map.replace!(:dy, dy2)

    Process.send_after(self(), :update, ceil(1000 / @fps))
    {:noreply, update_socket(socket, arena, player_1, player_2)}
  end

  #
  defp check_colisions(arena, x, y, dx, dy, team) do
    accumulator_data = {arena, x, y, dx, dy, team}
    {arena, x, y, dx, dy, _} = check_angles(0, :math.pi() * 2, :math.pi() / 4, accumulator_data)

    {arena, %{x: x, y: y, dx: dx, dy: dy}}
  end


  defp check_angles(angle, max_angle, step, {arena, x, y, dx, dy, team} = acc) when angle < max_angle do
    check_x = x + :math.cos(angle) * (@square_size / 2)
    check_y = y + :math.sin(angle) * (@square_size / 2)

    i = floor(check_x / @square_size)
    j = floor(check_y / @square_size)

    num_squares_x = @arena_size_x / @square_size
    num_squares_y = @arena_size_y / @square_size

    # debug(%{
    #   angle: angle,
    #   check_x: check_x,
    #   check_y: check_y,
    #   i: i, j: j,
    #   x: x, y: y
    # })

    if (i >= 0 && i < num_squares_x) && (j >= 0 && num_squares_y) && get_arena_cell_value(arena, i, j) != team do
      arena = update_arena_cell_value(arena, i, j, team)

      # Determine bounce direction based on the angle
      {dx, dy} = if abs(:math.cos(angle)) > abs(:math.sin(angle)) do
        {dx * -1, dy}
      else
        {dx, dy * -1}
      end

      dx = randomize_direction(dx)
      dy = randomize_direction(dy)

      check_angles(angle + step, max_angle, step, {
        arena, x, y, dx, dy, team
      })
    else
      check_angles(angle + step, max_angle, step, acc)
    end

  end
  defp check_angles(_, _, _, acc), do: acc


  defp check_boundary_collision(x, y, dx, dy) do
    dx = if (
      x + dx > @arena_size_x - @square_size / 2
      || x + dx < @square_size / 2
    ), do: -dx, else: dx

    dy = if (
      y + dy > @arena_size_y - @square_size / 2
      || y + dy < @square_size / 2
    ), do: -dy, else: dy

    {dx, dy}
  end


  def render(assigns) do
    ~L"""
      <div
        id="container"
        phx-hook="canvas"
        data-arena="<%= Jason.encode!(@arena) %>"
        data-player-1="<%= Jason.encode!(@player_1) %>"
        data-player-2="<%= Jason.encode!(@player_2) %>"
      >
        <canvas
          id="pong-wars-canvas"
          width="528"
          height="528"
          phx-update="ignore"
        > Canvas not supported :(
        </canvas>
      </div>
    """
  end


  # util
  defp get_arena_cell_value(arena, x, y) do
    Enum.at(Enum.at(arena, x), y)
  end

  defp update_arena_cell_value(arena, x, y, value) do
    updated_row = List.replace_at(Enum.at(arena, x), y, value)
    List.replace_at(arena, x, updated_row)
  end

  defp randomize_direction(d) do
    random = :rand.uniform() * 0.3 + 0.15
    d + random
  end

  defp _debug_arena(arena) do
    table = Enum.with_index(arena)
      |> Enum.map(fn {row, row_i} ->
        row_i = String.pad_leading("#{row_i}", 2, "0")
        Enum.with_index(row)
        |> Enum.map(fn {_col, col_i} ->
          col_i = String.pad_leading("#{col_i}", 2, "0")
          "(#{row_i}, #{col_i})"
        end)
        |> Enum.join(" | ")
      end)

    IO.inspect(table)
  end

end
