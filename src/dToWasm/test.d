extern(C): // disable D mangling

int print(double x);

double add(double a, double b) { return a + b; }

void printAdd(double a, double b) {
    print(add(a, b));
}
// seems to be the required entry point

version (WebAssembly)
    void _start() {}
else
    int main() {
        printAdd(5, 6);
        return 0;
    }