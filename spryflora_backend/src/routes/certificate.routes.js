import express from 'express';
import * as certController from '../controllers/certificate.controller.js';

const router = express.Router({ mergeParams: true });

router.get('/eligibility', certController.checkEligibility);
router.get('/', certController.getCertificate);

export default router;
