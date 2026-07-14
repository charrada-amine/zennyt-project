package com.zennyt.identity.application.port;

import com.zennyt.identity.application.model.CvParseData;

public interface CvParserPort {
    CvParseData parse(String text, String language);
}
