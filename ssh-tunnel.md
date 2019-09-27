# How to do tunnelling with ssh
```
ssh -XYCN -f  -L 5555:localhost:22  test
ssh -YNCD 10080 test
```
