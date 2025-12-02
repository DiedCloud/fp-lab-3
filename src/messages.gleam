import gleam/erlang/process

pub type Point {
  Point(x: Float, y: Float)
}

pub type InputMessage {
  NextPoint(point: Point, output_name: process.Subject(OuptputMassage))
  InputEOF
}

pub type OuptputMassage {
  Result(method_name: String, points: List(Point))
  OutputEOF
}

pub type GeneratorMessage {
  NextX(reply_to: process.Subject(List(Float)), start_x: Float, end_x: Float)
  EOF
}
