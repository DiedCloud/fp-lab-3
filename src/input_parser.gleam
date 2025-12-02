import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import input
import messages.{type InputMessage, type OuptputMassage}

pub fn start_input(
  alg_subjects: List(process.Subject(InputMessage)),
  output_subj: process.Subject(OuptputMassage),
) {
  io.println("Enter lines with two floats separated by space (`exit` to exit):")
  loop(alg_subjects, output_subj)
}

fn loop(
  alg_subjects: List(process.Subject(InputMessage)),
  output_subj: process.Subject(OuptputMassage),
) {
  let inp_res = input.input("")
  case inp_res {
    Ok("exit") -> {
      io.println("'exit' command captured. Sending EOF to processes")
      list.map(alg_subjects, process.send(_, messages.InputEOF))
      process.send(output_subj, messages.OutputEOF)
      io.println("EOFs sent, shutting down")
    }
    Ok(line) -> {
      case string.split(line, " ") {
        [x, y] -> {
          let x = case float.parse(x), int.parse(x) {
            Ok(x), _ -> Ok(x)
            _, Ok(x) -> Ok(int.to_float(x))
            _, _ -> Error(Nil)
          }

          let y = case float.parse(y), int.parse(y) {
            Ok(y), _ -> Ok(y)
            _, Ok(y) -> Ok(int.to_float(y))
            _, _ -> Error(Nil)
          }

          case x, y {
            Ok(x), Ok(y) -> {
              list.map(alg_subjects, process.send(
                _,
                messages.NextPoint(messages.Point(x, y), output_subj),
              ))
              Nil
            }
            _, _ -> io.println("You should input to numbers splitted by space")
          }
        }
        _ -> io.println("You should input to numbers splitted by space")
      }
      loop(alg_subjects, output_subj)
    }
    Error(_) -> {
      io.println("Failed to read line. Sending EOF to processes")
      list.map(alg_subjects, process.send(_, messages.InputEOF))
      process.send(output_subj, messages.OutputEOF)
      io.println("EOFs sent, shutting down")
    }
  }
}
