import * as d3 from 'd3';

// adapted from https://bl.ocks.org/mbostock/4063582
// eslint-disable-next-line no-unused-vars
export default function drawTreemap(data, onClick) {
  const id = 'treeMap';
  const svg = d3.select(`#${id}`);
  const { width, height } = document.getElementById(id).getBoundingClientRect();

  const fader = color => d3.interpolateRgb(color, '#fff')(0.2);
  const color = d3.scaleOrdinal(d3.schemeCategory20.map(fader));
  const format = d3.format(',d');

  const treemap = d3
    .treemap()
    .tile(d3.treemapResquarify)
    .size([width, height])
    .round(true)
    .paddingInner(1);

  const root = d3
    .hierarchy(data)
    .sum(d => d.size)
    .sort((a, b) => b.height - a.height || b.value - a.value);

  svg.selectAll('g').remove();

  treemap(root);

  const cell = svg
    .selectAll('g')
    .data(root.leaves())
    .enter()
    .append('g')
    .attr('transform', d => `translate(${d.x0},${d.y0})`);

  cell
    .append('rect')
    .attr('id', d => d.data.id)
    .attr('width', d => d.x1 - d.x0)
    .attr('height', d => d.y1 - d.y0)
    .attr('fill', d => color(d.parent.data.id));

  cell
    .append('clipPath')
    .attr('id', d => `clip-${d.data.id}`)
    .append('use')
    .attr('xlink:href', d => `#${d.data.id}`);

  cell
    .append('text')
    .attr('clip-path', d => `url(#clip-${d.data.id})`)
    .selectAll('tspan')
    .data(d => d.data.name.split(/(?=[A-Z][^A-Z])/g))
    .enter()
    .append('tspan')
    .attr('x', 4)
    .attr('y', (d, i) => 13 + i * 10)
    .text(d => d);

  cell.append('title').text(d => `${d.data.id}\n${format(d.value)}`);
}
