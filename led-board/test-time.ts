import { renderText } from "./src/dot-font.ts";

const time = "12:34";
const matrix = renderText(time, 1);

console.log("Time string:", time);
console.log("Matrix height:", matrix.length);
console.log("Matrix width:", matrix[0]?.length || 0);
console.log("\nDot matrix visualization:");

for (let r = 0; r < matrix.length; r++) {
  let row = "";
  for (let c = 0; c < (matrix[r]?.length || 0); c++) {
    row += matrix[r][c] ? "█" : " ";
  }
  console.log(row);
}
