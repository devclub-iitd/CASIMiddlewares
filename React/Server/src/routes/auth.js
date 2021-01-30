const express = require('express');
const { auth } = require('../middleware/auth');

const router = express.Router();

// check if user is logged in or not
router.get('/check', auth, (req, res) => {
    return res.status(200).json({
        success: true,
        data: {}
    })
})

export default router;