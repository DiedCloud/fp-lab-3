import gleam/erlang/process
import gleam/list
import messages.{type GeneratorMessage, type Point, InputEOF, NextPoint, Point}
import util
import x_generator

pub fn spawn_lagrange(
  creator_subj: process.Subject(process.Subject(messages.InputMessage)),
  step: Float,
  n: Int,
) {
  fn() {
    let this_subj: process.Subject(process.Subject(messages.GeneratorMessage)) =
      process.new_subject()
    process.spawn(x_generator.spawn_generator(this_subj, step))
    let generator_subj = process.receive_forever(this_subj)

    let this_subj: process.Subject(messages.InputMessage) =
      process.new_subject()
    process.send(creator_subj, this_subj)

    loop(generator_subj, [], this_subj, n)
  }
}

fn loop(
  generator_subj: process.Subject(GeneratorMessage),
  known: List(Point),
  this_subj: process.Subject(messages.InputMessage),
  n: Int,
) {
  let message = this_subj |> process.receive_forever()

  case message {
    NextPoint(Point(x, _y) as cur_point, output_subj) ->
      case list.length(known) == n - 1 {
        True -> {
          let xs_list =
            process.call_forever(generator_subj, messages.NextX(
              _,
              util.unsafe_list_at(known, 0).x,
              x,
            ))
          let res_list = list.map(xs_list, lagrange_interpolate(known, _))

          process.send(output_subj, messages.Result("Lagrange", res_list))

          let next_known = case known {
            [_to_drop, ..tail] -> list.append(tail, [cur_point])
            _ -> panic
          }

          loop(generator_subj, next_known, this_subj, n)
        }
        False ->
          loop(generator_subj, list.append(known, [cur_point]), this_subj, n)
      }

    InputEOF -> process.send(generator_subj, messages.EOF)
  }
}

pub fn lagrange_interpolate(points: List(Point), x: Float) {
  let f = fn(x_i: Float) {
    let not_eq = list.filter(points, fn(point_j) { point_j.x != x_i })
    let top =
      list.fold(not_eq, 1.0, fn(acc, point_j) { acc *. { x -. point_j.x } })
    let bot =
      list.fold(not_eq, 1.0, fn(acc, point_j) { acc *. { x_i -. point_j.x } })
    top /. bot
  }

  let y =
    list.fold(points, 0.0, fn(acc, point_i) { acc +. point_i.y *. f(point_i.x) })
  Point(x, y)
}
