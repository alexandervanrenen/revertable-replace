#include <iostream>
#include <regex>

using namespace std;

int main(int argc, char** argv)
{
  if(argc != 4) {
    cout << "wrong args" << endl;
    return -1;
  }

  cout << "argv=" << argv[1] << endl;
  
}
