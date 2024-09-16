use std::env;

use mathjax::MathJax;


// Can rewrite using https://github.com/RazrFalcon/resvg

fn main() {
    let args: Vec<String> = env::args().collect();
    let file_location = &args[1];
    let expression = &args[2];
    let renderer = MathJax::new().unwrap();
    let mut result = renderer.render(expression).unwrap();
    result.set_color("white");
    let image = result.into_image(10.0).unwrap(); // This is an image::DynamicImage.
    image.save(file_location).unwrap();
}
