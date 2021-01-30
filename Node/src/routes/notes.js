const express = require('express');
const Note = require('../models/note');

const router = express.Router();

// homepage for notes
router.get('/', async (req, res) => {
    const user_id = req.user.id;
    try {
        const userNotes = await Note.findOne({ user_id: user_id });
        if (!userNotes) {
            return res.render('notes', { empty: true, notes: '' });
        }
        const { notes } = userNotes;
        res.render('notes', { empty: false, notes: notes });
    } catch (err) {
        next(err);
    }
});

// post route to add a new note
router.post('/addNote', async (req, res) => {
    const user_id = req.user.id;
    const { noteHeading, noteBody } = req.body;
    try {
        const foundnotes = await Note.findOne({ user_id: user_id });

        if (!foundnotes) {
            insertNote = new Note({
                user_id,
                notes: [
                    {
                        noteHeading,
                        noteBody,
                    },
                ],
            });
            await insertNote.save();
        } else {
            const newNote = {
                noteHeading,
                noteBody,
            };
            await Note.findOneAndUpdate({ user_id: user_id }, { $push: { notes: newNote } });
        }
        return res.redirect('/notes');
    } catch (err) {
        next(err);
    }
});

router.post('/delete/:id', async (req, res) => {
    const { id } = req.params;
    const { uid } = req.user.id;
    try {
        await Note.deleteOne({
            notes: {
                _id: id,
            },
            user_id: uid,
        });
        res.redirect('/notes');
    } catch (err) {
        next(err);
    }
});

module.exports = router;
