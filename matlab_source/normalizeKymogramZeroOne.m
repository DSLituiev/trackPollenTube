function kymoThr = normalizeKymogramZeroOne(kymoThr)


kymoThr = double(kymoThr) - quantile(double(kymoThr(:)), 0.1);
kymoThr(kymoThr<0) = 0;
kymoThr = kymoThr./max(kymoThr(:)) ;
