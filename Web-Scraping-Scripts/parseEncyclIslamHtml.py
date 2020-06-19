import requests
import urllib.request
import time
from bs4 import BeautifulSoup
import csv

#This script takes a constructed query of the Encyclopaedia of Islam as its input and returns the headword, DOI, and abstract of the first search hit, if it exists.
class Entry:
    def __init__(self, doi, headword, abstract):
        self.doi = doi
        self.headword = headword
        self.abstract = abstract

def hasResults(resultsList):
    return resultsList.find('div', class_='result-item')

def encyclIslamLookup(url, parser="html.parser"):
    result = Entry('Search returned no results','Search returned no results','Search returned no results')
    #the above line will only be changed if there is a URL error or if a result is found. Does not gaurantee the result is correct.
    response = requests.get(url)
    if(not response):
        result.doi = "URL " + response.status_code + " error"
        result.headword = "URL " + response.status_code + " error"
        result.abstract = "URL " + response.status_code + " error"
        return result
    else:
        soup = BeautifulSoup(response.text, parser)
        resultsList = soup.section
        if (hasResults(resultsList)):
            doi = resultsList.div.next_sibling.next_sibling['data-itemid']
            doi = doi[len(doi)-8:len(doi)]
            result.doi = "http://dx.doi.org/10.1163/1573-3912_islam_" + doi
            result.headword = resultsList.div.next_sibling.next_sibling.h2.span.string
            result.abstract = resultsList.div.next_sibling.next_sibling.p.next_sibling.next_sibling.div.get_text().strip()
        return result

#Start of Script --- #
in_file = open("/Users/dhlab/Documents/GitHub/bethqatraye-preprocessing-scripts/htmlParseInputCsv.csv", mode='r')
reader = csv.reader(in_file, delimiter="\t", quotechar="'")
out_file = open("/Users/dhlab/Documents/GitHub/bethqatraye-preprocessing-scripts/htmlParseOutputCsv.csv", mode='w')
writer = csv.writer(out_file, delimiter="\t", quotechar="'")
lineCount = 0
lookupRow = 5
abstractRow = 7
abstractDoiRow = 8
headwordRow = 9
headwordDoiRow = 10

for row in reader:
    if(lineCount == 0):
        writer.writerow(row)
        lineCount += 1
    else:
        entry = encyclIslamLookup(row[lookupRow])
        row[abstractRow] = entry.abstract
        row[abstractDoiRow] = entry.doi
        row[headwordRow] = entry.headword
        row[headwordDoiRow] = entry.doi
        writer.writerow(row)
        lineCount += 1
        time.sleep(3)
print("Processed "+ str(lineCount) + " lines.")
in_file.close()
out_file.close()



# TEST CALL TO FUNCTION
# url = "https://referenceworks.brillonline.com/search?s.f.s2_parent=s.f.book.encyclopaedia-of-islam-2&search-go=&s.q=Bukhārā%20#%20Bukhara"
# entry = encyclIslamLookup(url)
# print(entry.doi)
# print(entry.headword)
# print(entry.abstract)




#FIRST TEST
# response = requests.get(url)
# print(response)
#
# soup = BeautifulSoup(response.text, "html.parser")
# results = soup.section
# doi = results.div.next_sibling.next_sibling['data-itemid']
# doi = doi[len(doi)-8:len(doi)]
# doi = "http://dx.doi.org/10.1163/1573-3912_islam_" + doi
# headword = results.div.next_sibling.next_sibling.h2.span.string
# abstract = results.div.next_sibling.next_sibling.p.next_sibling.next_sibling.div.string
# print(doi)
# print(headword)
# print(abstract)

# def encyclIslamLookup(url, parser ...a string with default 'html.parser'...)
# run the above code to look everything up
# return [doi, headword, abstract] or create a class.
# need to figure out how to handle errors: non-200 response; no search results (meaning the div ids are wrong); others?
