import gleam/erlang/process
import gleam/list
import messages.{type GeneratorMessage, type Point, InputEOF, NextPoint, Point}
import x_generator

pub fn spawn_lagrange(
  creator_subj: process.Subject(process.Subject(messages.InputMessage)),
) {
  fn() {
    let this_subj: process.Subject(process.Subject(messages.GeneratorMessage)) =
      process.new_subject()
    process.spawn(x_generator.spawn_generator(this_subj))
    let generator_subj = process.receive_forever(this_subj)

    let this_subj: process.Subject(messages.InputMessage) =
      process.new_subject()
    process.send(creator_subj, this_subj)

    loop(generator_subj, [], this_subj)
  }
}

fn loop(
  generator_subj: process.Subject(GeneratorMessage),
  known: List(Point),
  this_subj: process.Subject(messages.InputMessage),
) {
  let message = this_subj |> process.receive_forever()

  case message {
    NextPoint(Point(x, _y) as cur_point, step, output_subj) ->
      case known {
        [_, ..] -> {
          let xs_list =
            process.call_forever(generator_subj, messages.NextX(_, x, step))
          let res_list = list.map(xs_list, lagrange_interpolate(known, _))

          process.send(output_subj, messages.Result("Lagrange", res_list))

          loop(generator_subj, [cur_point, ..known], this_subj)
        }
        _ -> loop(generator_subj, [cur_point], this_subj)
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
