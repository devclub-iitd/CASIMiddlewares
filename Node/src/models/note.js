const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
    // here add all the rest of the features
    user_id : { type:String, required : true}, // this is to store user_id given by the auth server

    notes: [
        {
            noteHeading: {
                type: String,
            },
            noteBody: {
                type: String,
            },
            creationDate: {
                type: Date,
                default: Date.now,
            },
        },
    ]
});

module.exports = mongoose.model('Note', noteSchema);
