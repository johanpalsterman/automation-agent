const express = require('express');
const path = require('path');

const app = express();
const PORT = 5000;

app.disable('x-powered-by');

app.get('*', (req, res) => {
  res.setHeader('Cache-Control', 'no-cache');
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Dashboard server luistert op poort ' + PORT);
});
