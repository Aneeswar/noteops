const request = require('supertest');
const express = require('express');
const { v4: uuidv4 } = require('uuid');

// Mock server for unit testing without full server startup
const app = express();
app.use(express.json());

let notes = [];
app.get('/health', (req, res) => res.status(200).json({ status: 'UP', version: '2.0.0' }));
app.get('/notes', (req, res) => res.json(notes));
app.post('/notes', (req, res) => {
  const { title, body } = req.body;
  if (!title || !body) return res.status(400).json({ error: 'Title and body are required' });
  const newNote = { id: uuidv4(), title, body, createdAt: new Date() };
  notes.push(newNote);
  res.status(201).json(newNote);
});

describe('Notes API Unit Tests', () => {
  beforeEach(() => {
    notes = [];
  });

  test('GET /health should return UP', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('UP');
  });

  test('POST /notes should create a note', async () => {
    const res = await request(app)
      .post('/notes')
      .send({ title: 'Test Note', body: 'This is a test' });
    expect(res.statusCode).toBe(201);
    expect(res.body.title).toBe('Test Note');
    expect(notes.length).toBe(1);
  });

  test('POST /notes should fail without body', async () => {
    const res = await request(app)
      .post('/notes')
      .send({ title: 'Test Note' });
    expect(res.statusCode).toBe(400);
  });
});
