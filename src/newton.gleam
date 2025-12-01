import gens/lazy
import gleam/erlang/process
import gleam/list

import messages.{type GeneratorMessage, type Point, InputEOF, NextPoint, Point}
import x_generator

pub fn spawn_newton(
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
          let res_list = list.map(xs_list, newton_interpolate(known, _))

          process.send(output_subj, messages.Result("Newton", res_list))

          loop(generator_subj, list.append(known, [cur_point]), this_subj)
        }
        _ -> loop(generator_subj, [cur_point], this_subj)
      }

    InputEOF -> process.send(generator_subj, messages.EOF)
  }
}

pub fn newton_interpolate(points: List(Point), x: Float) {
  let #(xs, ys) = points |> list.map(fn(p) { #(p.x, p.y) }) |> list.unzip

  let y =
    list.fold(
      // от 1 до lenth-1
      lazy.new() |> lazy.map(fn(a) { a + 1 }) |> lazy.take(list.length(xs) - 1),
      case ys {
        [s, ..] -> s
        _ -> panic
      },
      fn(acc, k) {
        acc +. calc_y_delta_divided(k, 0, xs, ys) *. calc_t(k, x, xs)
      },
    )
  Point(x, y)
}

// k=0: 1; k=1: (x-x_0); k=2: (x-x_0)(x-x_1)
fn calc_t(k: Int, x: Float, xs: List(Float)) -> Float {
  list.fold(lazy.new() |> lazy.take(k), 1.0, fn(acc, i) {
    acc *. { x -. unsafe_list_at(xs, i) }
  })
}

fn calc_y_delta_divided(
  k: Int,
  i: Int,
  xs: List(Float),
  ys: List(Float),
) -> Float {
  case k <= 0 {
    True -> unsafe_list_at(ys, i)
    False ->
      {
        calc_y_delta_divided(k - 1, i + 1, xs, ys)
        -. calc_y_delta_divided(k - 1, i, xs, ys)
      }
      /. { unsafe_list_at(xs, i + k) -. unsafe_list_at(xs, i) }
  }
}

fn unsafe_list_at(l: List(a), index: Int) -> a {
  case l {
    [head, ..tail] ->
      case index <= 0 {
        True -> head
        False -> unsafe_list_at(tail, index - 1)
      }
    _ -> panic
  }
}
