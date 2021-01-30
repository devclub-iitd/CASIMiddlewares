import React from 'react';
import classes from '../styles/notes.module.css';

const Notes = () => {
    return (
        <div className={classes.rootContainer}>
            <div className={[classes.half, classes.half1].join(' ')}>
                <div className={classes.notes}>
                    <div className={classes.note}>
                        <div className={classes.noteHeading}>
                            <h5>Heading</h5>
                            <form action="/notes/delete/noteid" method="post">
                                <button
                                    type="submit"
                                    className={classes.delBtn}
                                >
                                    Delete Note
                                </button>
                            </form>
                        </div>
                        <div className={classes.noteBody}>
                            <p>
                                Lorem ipsum dolor sit amet consectetur
                                adipisicing elit. Aliquam facere doloribus sint
                                repellendus quis officiis tenetur labore iusto,
                                nisi reprehenderit tempore quasi dolor quidem
                                deleniti ipsam ut ipsum provident soluta.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
            <div className={classes.half}>
                <div className={classes.formContainer}>
                    <form
                        id="addNoteForm"
                        action="/notes/addNote"
                        method="POST"
                        style={{ textAlign: 'center' }}
                    >
                        <input
                            type="text"
                            name="noteHeading"
                            placeholder="Note Title"
                            required
                        />
                        <br />
                        <br />
                        <textarea
                            name="noteBody"
                            placeholder="Note Body"
                            id=""
                            cols="30"
                            rows="10"
                            required
                        />
                        <br />
                        <br />
                        <button
                            type="submit"
                            className={classes.btn}
                            style={{ margin: '20px auto' }}
                        >
                            Add
                        </button>
                    </form>
                    <br />
                    <br />
                    <b>OR</b>
                    <br />
                    <br />
                    <a href="/home">
                        <div className={classes.btn}>Home</div>
                    </a>
                </div>
            </div>
        </div>
    );
};

export default Notes;
