#include <iostream>
#include <regex>
#include <cassert>
#include <cmath>
#include <fcntl.h>
#include <sstream>
#include <sys/stat.h>
#include <unistd.h>
#include <array>
#include <zconf.h>
#include <cstdint>
#include <fstream>

using namespace std;

uint64_t getFileLength(const string &file_name)
{
   int fileFD = open(file_name.c_str(), O_RDWR);
   if (fileFD<0) {
      cout << "unable to open file:" << file_name << endl; // You can check errno to see what happend
      throw;
   }
   if (fcntl(fileFD, F_GETFL) == -1) {
      cout << "unable to call fcntl on file:" << file_name << endl; // You can check errno to see what happend
      throw;
   }
   struct stat st;
   fstat(fileFD, &st);
   close(fileFD);
   return st.st_size;
}

string loadFileToMemory(const string &file_name)
{
   uint64_t length = getFileLength(file_name);
   string data(length, 'a');
   ifstream in(file_name);
   in.read(&data[0], length);
   return data;
}

int main(int argc, char** argv)
{
  if(argc != 4) {
    cout << "wrong args " << argc << endl;
    return -1;
  }

  bool is_regex = false;
  string search_pattern = argv[1];
  string replacement_word = argv[2];
  string file_name = argv[3];

  string file_content = loadFileToMemory(file_name);

  if(is_regex) {
    // regex matcher: slower than sed :(
    regex pattern(search_pattern);
    smatch res;
    unsigned last_position = 0;
    while (regex_search(file_content.cbegin() + last_position, file_content.cend(), res, pattern)) {
        cout.write(&file_content[last_position], res.position());
        cout.write(replacement_word.c_str(), replacement_word.size());
        last_position += res.position() + res.length();
    }
    cout.write(&file_content[last_position], file_content.size() - last_position);
  } else {
    // normal matcher: faster than sed :)
    int last_position = 0;
    for(int i=0; i<file_content.size(); i++) {
      int j = 0;
      while(j<search_pattern.size() && i+j<file_content.size() && file_content[i+j] == search_pattern[j]) {
        j++;
      }
      if(j == search_pattern.size()) {
        cout.write(&file_content[last_position], i - last_position);
        cout.write(replacement_word.c_str(), replacement_word.size());
        i += j;
        last_position = i;
      }
    }
    cout.write(&file_content[last_position], file_content.size() - last_position);
  }
}
