const express = require('express');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let notes = [];

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

// Create a note
app.post('/notes', (req, res) => {
  const { title, body } = req.body;
  if (!title || !body) {
    return res.status(400).json({ error: 'Title and body are required' });
  }
  const newNote = { id: uuidv4(), title, body, createdAt: new Date() };
  notes.push(newNote);
  res.status(201).json(newNote);
});

// List all notes
app.get('/notes', (req, res) => {
  res.json(notes);
});

// Get single note
app.get('/notes/:id', (req, res) => {
  const note = notes.find(n => n.id === req.params.id);
  if (!note) return res.status(404).json({ error: 'Note not found' });
  res.json(note);
});

// Update a note
app.put('/notes/:id', (req, res) => {
  const { title, body } = req.body;
  const index = notes.findIndex(n => n.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Note not found' });
  
  notes[index] = { ...notes[index], title: title || notes[index].title, body: body || notes[index].body };
  res.json(notes[index]);
});

// Delete a note
app.delete('/notes/:id', (req, res) => {
  const index = notes.findIndex(n => n.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Note not found' });
  
  notes.splice(index, 1);
  res.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
