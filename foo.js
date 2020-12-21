var Mercury = require("@postlight/mercury-parser");

const url="https://aeon.co/essays/boudica-how-a-widowed-queen-became-a-rebellious-woman-warrior";
Mercury.parse(url).then(result => console.log(result));