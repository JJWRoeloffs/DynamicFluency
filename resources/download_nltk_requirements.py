def main():
    print("Starting process")
    test_sentence = "This is the sentence the downloaded data will be tested on"

    try:
        import nltk
    except ImportError:
        print("Please install nltk. It is currently not installed (correctly)")

    else:
        nltk.download("punkt")
        test_tokens = nltk.word_tokenize(test_sentence)
        print("Tokeniser downloaded succesfully")


        nltk.download("averaged_perceptron_tagger")
        test_tags = nltk.pos_tag(test_tokens)
        print("Tagger downloaded succesfully. Finishing process")

if __name__ == "__main__":
    main()
