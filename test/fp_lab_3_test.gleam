import gleeunit
import lagrange
import linear
import messages
import newton

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn linear_test() {
  let a = messages.Point(0.0, 0.0)
  let b = messages.Point(1.25, 1.0)
  assert linear.linear_interpolate(a, b, 1.0) == messages.Point(1.0, 0.8)
  assert linear.linear_interpolate(a, b, 2.0) == messages.Point(2.0, 1.6)
}

pub fn lagrange_test() {
  let a = [messages.Point(0.0, 0.0), messages.Point(1.25, 1.0)]
  assert lagrange.lagrange_interpolate(a, 1.0) == messages.Point(1.0, 0.8)
  assert lagrange.lagrange_interpolate(a, 2.0) == messages.Point(2.0, 1.6)

  let a = [
    messages.Point(0.0, 0.0),
    messages.Point(2.0, 4.0),
    messages.Point(4.0, 0.0),
  ]
  assert lagrange.lagrange_interpolate(a, 1.0) == messages.Point(1.0, 3.0)
  assert lagrange.lagrange_interpolate(a, 3.0) == messages.Point(3.0, 3.0)
}

pub fn newton_test() {
  let a = [messages.Point(0.0, 0.0), messages.Point(1.25, 1.0)]
  assert newton.newton_interpolate(a, 1.0) == messages.Point(1.0, 0.8)
  assert newton.newton_interpolate(a, 2.0) == messages.Point(2.0, 1.6)

  let a = [
    messages.Point(0.0, 0.0),
    messages.Point(2.0, 4.0),
    messages.Point(4.0, 0.0),
  ]
  assert newton.newton_interpolate(a, 1.0) == messages.Point(1.0, 3.0)
  assert newton.newton_interpolate(a, 3.0) == messages.Point(3.0, 3.0)
}
