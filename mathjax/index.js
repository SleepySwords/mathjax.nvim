const sharp = require('sharp');
const filename = process.argv[2]
const colour = process.argv[3]
const latex = process.argv.slice(4).join(" ")
console.log(filename)
console.log(latex)


require('mathjax').init({
  loader: { load: ['input/tex', 'output/svg'] }
}).then((MathJax) => {
  const texSvg = MathJax.tex2svg(latex, { display: true });
  let svg = MathJax.startup.adaptor.outerHTML(texSvg)
  svg = svg.replace('<mjx-container class="MathJax" jax="SVG" display="true">', '')
  svg = svg.replace('</mjx-container>', '')
  svg = svg.replaceAll('currentColor', colour)
  console.log(svg)
  const mathJaxSvg = Buffer.from(svg);
  sharp(mathJaxSvg, { density: 300 })
    .png()
    .toFile(filename)
}).catch((err) => console.log(err.message));

