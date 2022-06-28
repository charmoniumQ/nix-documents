n = 100
for i in range(1,n+1):
    result = ""
    if i % 3 == 0:
        result += "Fizz"
    if i % 5 == 0:
        result += "Buzz"
    if result == "":
        result = str(i)
# Test latex in comments
# \LaTeX
# Test math mode in comments
# $\int x^2 \, \mathrm{d}x$
