alias compresspdfs='command -v "gs" >"/dev/null" && \
                    export PDFS_OUT_DIR="compressedpdfs-$(date -u "+%Y%m%dT%H%M%SZ")" && \
                    mkdir -p "./${PDFS_OUT_DIR}" && \
                    find . -type f -name "*.pdf" -exec \
                        sh -c '\''gs -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite \
                                -dCompatibilityLevel=1.3 -dPDFSETTINGS=/screen \
                                -dEmbedAllFonts=true -dSubsetFonts=true \
                                -dColorImageDownsampleType=/Bicubic -dColorImageResolution=144 \
                                -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=144 \
                                -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=144 \
                                -sOutputFile="./${PDFS_OUT_DIR}/$(basename "{}")" \
                                "{}" \
                        '\'' \;'
