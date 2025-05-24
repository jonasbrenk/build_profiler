#include <stdio.h>
#include "my_lib.h" // Include the custom library header

int main() {
    printf("Starting the main application.\n");
    print_greeting(); // Call a function from my_lib
    int answer = get_answer();
    printf("The retrieved answer is: %d\n", answer);
    return 0;
}