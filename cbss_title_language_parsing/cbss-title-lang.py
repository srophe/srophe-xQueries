from lingua import Language, LanguageDetectorBuilder
import pandas as pd

FILEPATH = "/home/arren/Documents/Work_Syriaca/cbss_lang-detect.csv"
OUTPATH = "/home/arren/Documents/Work_Syriaca/cbss_lang-detect_PARSED.csv"

data = pd.read_csv(FILEPATH)
data["auto title language"] = ""

detector = LanguageDetectorBuilder.from_all_languages_without(Language.BOKMAL).with_preloaded_language_models().build()
"""
LanguageDetectorBuilder.from_all_languages_without(Language.SPANISH)
- exclude Norwegian Bokmal (nb)?
- refine this
"""

for i, row in data.iterrows():
    title = row["title"]
    try:
        language = detector.detect_language_of(title)
        # Must use df.at to actually modify the value (iterrows returns copies...)
        data.at[i, "auto title language"] = language.iso_code_639_1.name.lower()
    except:
        print(row)

data.to_csv(OUTPATH, index=False)