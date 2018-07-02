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
  if(argc != 2) {
    cout << "wrong args " << argc << endl;
    return -1;
  }

  string file_name = argv[1];
  string file_content = loadFileToMemory(file_name);
  istringstream is(file_content);

  string pre_inlcudes;
  string post_includes;
  vector<string> includes;

  enum struct Phase {BEFORE_INCLUDES, DURING_INCLUDES, AFTER_INCLUDES};
  Phase phase = Phase::BEFORE_INCLUDES;

  string line = "";
  int line_num = 0;
  int chars_read = 0;
  while(is.good()) {
      // Get next line
      line_num++;
      int start_of_line = chars_read;
      getline(is, line);
      chars_read += line.size() + 1;

      // Check for inlcude
      size_t include_pos = line.find("#include");

      // We found no inlcude
      if(include_pos == string::npos) {
          if(phase == Phase::DURING_INCLUDES) {
              post_includes = file_content.substr(start_of_line, string::npos);
              phase = Phase::AFTER_INCLUDES;
          }
          continue;
      }

      // We found a bad include
      if(include_pos != 0) {
          continue;
      }

      // We found a regular include
      switch (phase) {
          case Phase::BEFORE_INCLUDES:
              pre_inlcudes = file_content.substr(0, start_of_line);
              phase = Phase::DURING_INCLUDES;
          case Phase::DURING_INCLUDES:
              includes.push_back(line);
              break;
          case Phase::AFTER_INCLUDES:
              cerr << "bad include in line " << line_num << endl;
              break;
      }
   }

   sort(includes.begin(), includes.end());

   cout << pre_inlcudes;
   for(auto& iter : includes) {
       cout << iter << endl;
   }
   cout << post_includes;
}
