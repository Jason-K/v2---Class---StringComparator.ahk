#Requires AutoHotkey v2.0

; CREDIT TO THQBY, WHOSE PY4AHK DOES ALL - AND I DO MEAN ALL - OF THE HEAVY LIFTING HERE.
; I DON'T SEE THAT @THQBY HAS A ASSIGNED A SPECIFIC LICENSE TO PY4AHK, SO I'M GOING TO ASSUME THAT IT'S FREE TO USE.
; IF NOT, PLEASE LET ME KNOW AND I'LL REMOVE THIS SCRIPT IMMEDIATELY.
; https://github.com/thqby/pyahk
; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=105544&p=468780&hilit=python#p468780

; ADDITIONAL CREDIT TO THE CONTRIBUTORS TO THE JELLYFISH, FUZZYWUZZY, AND SCIKIT-LEARN LIBRARIES FOR PYTHON
; IF PY4AHK IS WHAT MAKES THIS SCRIPT WORK, IT IS THEIR WORK THAT  MAKES IT USEFUL.

; Turk, James. "jellyfish" v1.0.0, 2023-06-21. Available at: https://github.com/jamesturk/jellyfish, ORCID: https://orcid.org/0000-0003-1762-1420. ;
; Installed via pip, "pip install jellyfish"

; Cohen, Adam. "TheFuzz" Available at: https://github.com/seatgeek/thefuzz.
; Released under MIT License.
; Installed via pip, "pip install thefuzz"

; Pedregosa et al., "Scikit-learn: Machine Learning in Python," JMLR 12, pp. 2825-2830, 2011. Available at: http://scikit-learn.org/.
; Released under the BSD 3-Clause License.
; Installed via pip, "pip install scikit-learn"

#Include <v2 - Class - py4ahk>

class StringComparator {
    static py := ""

    ; Path to the Python DLL. THQBY defaulted to Python 3.9, but I'm using Python 3.12 without any problems for this very limited implementation.
    static dllPath := "C:\Users\" A_UserName "\AppData\Local\Programs\Python\Python312\python312.dll"

    static __New() {
        this.py := Python(this.dllPath)
        this.InitializePython()
    }

    static InitializePython() {

        ; Import necessary libraries and define comparison functions
        pyScript := "
                (
                import jellyfish

                from thefuzz import fuzz
                from thefuzz import process
                
                from sklearn.feature_extraction.text import CountVectorizer
                from sklearn.metrics.pairwise import cosine_similarity
                
                import numpy as np

                def levenshtein_distance(str1, str2, threshold = 3):
                    return jellyfish.levenshtein_distance(str1, str2) <= threshold, jellyfish.levenshtein_distance(str1, str2)

                def damerau_levenshtein_distance(str1, str2, threshold = 3):
                    return jellyfish.damerau_levenshtein_distance(str1, str2) <= threshold, jellyfish.damerau_levenshtein_distance(str1, str2)

                def hamming_distance(str1, str2, threshold = 3):
                    return jellyfish.hamming_distance(str1, str2) <= threshold, jellyfish.hamming_distance(str1, str2)

                def jaro_similarity(str1, str2, threshold = 0.8):
                    return jellyfish.jaro_similarity(str1, str2) >= threshold, jellyfish.jaro_similarity(str1, str2)

                def jaro_winkler_similarity(str1, str2, threshold = 0.8):
                    return jellyfish.jaro_winkler_similarity(str1, str2) >= threshold, jellyfish.jaro_winkler_similarity(str1, str2)

                def match_rating_approach(str1, str2):
                    return jellyfish.match_rating_comparison(str1, str2), jellyfish.match_rating_codex(str1), jellyfish.match_rating_codex(str2)

                def jaccard_similarity(str1, str2, threshold = 0.8):
                    return jellyfish.jaccard_similarity(str1, str2) >= threshold, jellyfish.jaccard_similarity(str1, str2)

                def soundex_match(str1, str2):
                    return jellyfish.soundex(str1) == jellyfish.soundex(str2), jellyfish.soundex(str1), jellyfish.soundex(str2)

                def metaphone_match(str1, str2):
                    return jellyfish.metaphone(str1) == jellyfish.metaphone(str2), jellyfish.metaphone(str1), jellyfish.metaphone(str2)

                def nysiis_match(str1, str2):
                    return jellyfish.nysiis(str1) == jellyfish.nysiis(str2), jellyfish.nysiis(str1), jellyfish.nysiis(str2)

                def match_rating_codex(str1, str2):
                    return jellyfish.match_rating_codex(str1) == jellyfish.match_rating_codex(str2), jellyfish.match_rating_codex(str1), jellyfish.match_rating_codex(str2)

                def sorensen_dice_similarity(str1, str2, threshold = 0.8):
                    set1 = set(str1.lower())
                    set2 = set(str2.lower())
                    intersection = len(set1.intersection(set2))
                    score = (2.0 * intersection) / (len(set1) + len(set2))
                    return score >= threshold, score

                def cosine_similarity_check(str1, str2, threshold = 0.8):
                    vectorizer = CountVectorizer().fit_transform([
                        str1,
                        str2
                    ])
                    vectors = vectorizer.toarray()
                    csim = cosine_similarity(vectors)
                    return csim[0, 1] >= threshold, csim[0, 1]

                def fuzzywuzzy_ratio(str1, str2, threshold=80):
                    score = fuzz.ratio(str1, str2)
                    return score >= threshold, score

                def fuzzywuzzy_partial_ratio(str1, str2, threshold=80):
                    score = fuzz.partial_ratio(str1, str2)
                    return score >= threshold, score

                def fuzzywuzzy_token_sort_ratio(str1, str2, threshold=80):
                    score = fuzz.token_sort_ratio(str1, str2)
                    return score >= threshold, score

                def fuzzywuzzy_token_set_ratio(str1, str2, threshold=80):
                    score = fuzz.token_set_ratio(str1, str2)
                    return score >= threshold, score
                )"

        this.py.exec(pyScript)
    }

    static Compare(method, str1, str2, threshold := "") {
        str1 := StrReplace(str1, "'", "\'")
        str2 := StrReplace(str2, "'", "\'")

        if (threshold != "") {
            pythonCall := Format("{1}('{2}', '{3}', {4})", method, str1, str2, threshold)
        } else {
            pythonCall := Format("{1}('{2}', '{3}')", method, str1, str2)
        }

        result := this.py.eval(pythonCall)

        ; Extract boolean result and score
        bool := result[0]
        score := ""
        encodings := ""

        ; Handle different return types based on the method
        if (method ~= "soundex|metaphone|nysiis|match_rating_codex") {
            score := bool    ; For these methods, the boolean result is the "score"
            encodings := [
                result[1],
                result[2]
            ]    ; Phonetic encodings
        } else {
            score := result[1]    ; Numerical score or other result
        }

        return {
            method: method,
            str1: str1,
            str2: str2,
            threshold: threshold,
            bool: bool,
            score: score,
            encodings: encodings
        }
    }

    ; Levenshtein Distance: The Levenshtein distance algorithm is a way to measure the difference between two strings of text. It is also known as the edit distance, because it calculates the minimum number of operations needed to transform one string into the other. This can be useful in a variety of applications, such as spelling correction and natural language processing.
    ; Threshold: The maximum number of edits allowed for the strings to be considered similar.
    static LevenshteinDistance(str1, str2, threshold := 3) {
        return this.Compare("levenshtein_distance", str1, str2, threshold)
    }

    ; Damerau-Levenshtein Distance: Damerau-Levenshtein with optimal string alignment distance, also known as Damerau-Levenshtein with OSA distance, is a string metric for measuring the difference between two sequences. It is a variant of the Damerau-Levenshtein distance algorithm, which allows for the use of adjacent transpositions. In addition to this, the OSA variant also takes into account the possibility of inserting additional characters into the strings being compared in order to align them more closely. This means that the algorithm can more accurately measure the difference between two strings that may have different lengths or may not be perfectly aligned with each other.
    ; Threshold: The maximum number of edits (including transpositions) allowed for the strings to be considered similar.
    static DamerauLevenshteinDistance(str1, str2, threshold := 3) {
        return this.Compare("damerau_levenshtein_distance", str1, str2, threshold)
    }

    ; Hamming Distance: Measures the number of positions at which the corresponding characters are different.
    ; Threshold: The maximum number of differing positions allowed for the strings to be considered similar.
    static HammingDistance(str1, str2, threshold := 3) {
        return this.Compare("hamming_distance", str1, str2, threshold)
    }

    ; Jaro Similarity: The Jaro similarity algorithm is a measure of the similarity between two strings. It is commonly used in natural language processing and information retrieval to calculate the similarity between two strings of text. The Jaro similarity algorithm compares the two strings character by character, taking into account the number of matching characters and the number of transpositions (or character swaps) needed to transform one string into the other. The resulting similarity score ranges from 0, indicating that the two strings are completely different, to 1, indicating that the two strings are identical.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static JaroSimilarity(str1, str2, threshold := 0.8) {
        return this.Compare("jaro_similarity", str1, str2, threshold)
    }

    ; Jaro-Winkler Similarity: The Jaro-Winkler distance algorithm is a measure of the similarity between two strings. It is a variant of the Jaro similarity algorithm, which compares the two strings character by character and takes into account the number of matching characters and the number of transpositions needed to transform one string into the other. The Jaro-Winkler distance algorithm adds a prefix bonus to the Jaro similarity score, which gives additional weight to matching characters that appear at the beginning of the strings being compared. This helps the algorithm to more accurately measure the similarity between strings that may have similar but not necessarily identical prefixes. The resulting Jaro-Winkler distance ranges from 0, indicating that the two strings are completely different, to 1, indicating that the two strings are identical.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static JaroWinklerSimilarity(str1, str2, threshold := 0.8) {
        return this.Compare("jaro_winkler_similarity", str1, str2, threshold)
    }

    ; Match Rating Approach: A phonetic algorithm for matching names.
    ; No threshold is used for this method.
    static MatchRatingApproach(str1, str2) {
        return this.Compare("match_rating_approach", str1, str2)
    }

    ; Jaccard Similarity: The Jaccard similarity coefficient, also known as the Jaccard index, is a measure of similarity between two sets. It is defined as the size of the intersection of the two sets divided by the size of the union of the two sets. The Jaccard similarity coefficient ranges from 0, indicating that the two sets have no elements in common, to 1, indicating that the two sets are identical. This metric is commonly used in a variety of fields, including natural language processing and recommendation systems, to calculate the similarity between two sets of data.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static JaccardSimilarity(str1, str2, threshold := 0.8) {
        return this.Compare("jaccard_similarity", str1, str2, threshold)
    }

    ; Soundex Match: The Soundex algorithm is a phonetic algorithm for indexing words by their pronunciation. It is commonly used for proper nouns, such as personal names, but can also be applied to other words. The algorithm assigns a unique code to each word based on the way it sounds when spoken. This code can then be used to index the word in a database or other data structure, allowing it to be searched and compared with other words. The Soundex algorithm is based on the idea of "soundalikes" – words that are spelled differently but sound the same when spoken. It uses a set of rules to convert words into a standardized code, with the goal of ensuring that words with the same pronunciation will have the same code. This allows words with similar pronunciations to be grouped together and searched efficiently.
    ; No threshold is used for this method.
    static SoundexMatch(str1, str2) {
        return this.Compare("soundex_match", str1, str2)
    }

    ; Metaphone Match: The Metaphone algorithm is a phonetic algorithm for indexing words by their pronunciation. It is commonly used for proper nouns, such as personal names, but can also be applied to other words. The algorithm assigns a unique code to each word based on the way it sounds when spoken. This code can then be used to index the word in a database or other data structure, allowing it to be searched and compared with other words. The Metaphone algorithm is an improved version of the Soundex algorithm, which was design ed to address some of the limitations of Soundex. It uses a more advanced set of rules to convert words into a standardized code, with the goal of improving the accuracy of the matches and reducing the number of false positives. Like Soundex, the Metaphone algorithm is commonly used in applications such as spelling correction and speech recognition.
    ; No threshold is used for this method.
    static MetaphoneMatch(str1, str2) {
        return this.Compare("metaphone_match", str1, str2)
    }

    ; NYSIIS Match: Encodes strings into a phonetic representation to compare their sounds.
    ; No threshold is used for this method.
    static NYSIISMatch(str1, str2) {
        return this.Compare("nysiis_match", str1, str2)
    }

    ; Match Rating Codex: Encodes strings into a phonetic representation to compare their sounds.
    ; No threshold is used for this method.
    static MatchRatingCodex(str1, str2) {
        return this.Compare("match_rating_codex", str1, str2)
    }

    ; Sorensen-Dice Similarity: The Sorensen-Dice coefficient is a statistic used to gauge the similarity of two samples. It's calculated as twice the number of elements common to both sets divided by the sum of the number of elements in each set. This method is particularly useful for comparing the similarity of two strings based on their character composition.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static SorensenDiceSimilarity(str1, str2, threshold := 0.8) {
        return this.Compare("sorensen_dice_similarity", str1, str2, threshold)
    }

    ; Cosine Similarity: Cosine similarity measures the cosine of the angle between two non-zero vectors in an inner product space. In the context of string comparison, it's used to measure the similarity between two strings by treating them as vectors in a multi-dimensional space where each dimension corresponds to a term (usually a word) in the document.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static CosineSimilarity(str1, str2, threshold := 0.8) {
        return this.Compare("cosine_similarity_check", str1, str2, threshold)
    }

    ; FuzzyWuzzy Ratio: This method calculates the Levenshtein distance between two sequences in a simple way.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static FuzzyRatio(str1, str2, threshold := 80) {
        return this.Compare("fuzzywuzzy_ratio", str1, str2, threshold)
    }

    ; FuzzyWuzzy Partial Ratio: This method attempts to find the best matching substring between two strings.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static FuzzyPartialRatio(str1, str2, threshold := 80) {
        return this.Compare("fuzzywuzzy_partial_ratio", str1, str2, threshold)
    }

    ; FuzzyWuzzy Token Sort Ratio: This method tokenizes the strings, sorts the tokens alphabetically, and then joins them back into strings before calculating the ratio.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static FuzzyTokenSortRatio(str1, str2, threshold := 80) {
        return this.Compare("fuzzywuzzy_token_sort_ratio", str1, str2, threshold)
    }

    ; FuzzyWuzzy Token Set Ratio: This method tokenizes the strings and calculates the ratio based on the intersection of the tokens.
    ; Threshold: The minimum similarity score required for the strings to be considered similar.
    static FuzzyTokenSetRatio(str1, str2, threshold := 80) {
        return this.Compare("fuzzywuzzy_token_set_ratio", str1, str2, threshold)
    }
}

; Function to compare two strings using various methods and display the results

CompareAndDisplayResults(str1, str2) {
    results := Map(
        "Levenshtein Distance (≤3)", StringComparator.LevenshteinDistance(str1, str2),
        "Damerau-Levenshtein Distance (≤3)", StringComparator.DamerauLevenshteinDistance(str1, str2),
        "Hamming Distance (≤3)", StringComparator.HammingDistance(str1, str2),
        "Jaro Similarity (≥0.8)", StringComparator.JaroSimilarity(str1, str2),
        "Jaro-Winkler Similarity (≥0.8)", StringComparator.JaroWinklerSimilarity(str1, str2),
        "Match Rating Approach", StringComparator.MatchRatingApproach(str1, str2),
        "Jaccard Similarity (≥0.8)", StringComparator.JaccardSimilarity(str1, str2),
        "Soundex Match", StringComparator.SoundexMatch(str1, str2),
        "Metaphone Match", StringComparator.MetaphoneMatch(str1, str2),
        "NYSIIS Match", StringComparator.NYSIISMatch(str1, str2),
        "Match Rating Codex", StringComparator.MatchRatingCodex(str1, str2),
        "Sorensen-Dice Similarity (≥0.8)", StringComparator.SorensenDiceSimilarity(str1, str2),
        "Cosine Similarity (≥0.8)", StringComparator.CosineSimilarity(str1, str2),
        "TheFuzz Ratio (≥80)", StringComparator.FuzzyRatio(str1, str2),
        "TheFuzz Partial Ratio (≥80)", StringComparator.FuzzyPartialRatio(str1, str2),
        "TheFuzz Token Sort Ratio (≥80)", StringComparator.FuzzyTokenSortRatio(str1, str2),
        "TheFuzz Token Set Ratio (≥80)", StringComparator.FuzzyTokenSetRatio(str1, str2)
    )

    output := "Comparison Results:`n`n"
    output .= Format("String 1: {1}`nString 2: {2}`n`n", str1, str2)

    for method, result in results {
        output .= Format("{1}:`n", method)
        output .= Format("  Result: {1}`n", result.bool ? "True" : "False")
        if (result.threshold != "")
            output .= Format("  Threshold: {1}`n", result.threshold)

        ; Format score
        if (IsNumber(result.score)) {
            output .= Format("  Score: {1:.4f}`n", result.score)
        } else if (result.score != "") {
            output .= Format("  Score: {1}`n", result.score)
        }

        ; Add encodings if available
        if (result.encodings) {
            output .= Format("  Encoding 1: {1}`n", result.encodings[1])
            output .= Format("  Encoding 2: {1}`n", result.encodings[2])
        }

        output .= "`n"
    }

    MsgBox output
}

CompareAndDisplayResults("hello world", "hello there")
