import { CertificateService } from '../services/certificate.service.js';

export const checkEligibility = async (req, res, next) => {
  try {
    const result = await CertificateService.checkEligibility(req.user.id, req.params.plantId);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const getCertificate = async (req, res, next) => {
  try {
    const cert = await CertificateService.getCertificate(req.user.id, req.params.plantId);
    res.status(200).json(cert);
  } catch (error) {
    next(error);
  }
};
