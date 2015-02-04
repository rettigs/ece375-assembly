#!/usr/bin/env python

def mul(a, b):
    '''Multiplies the n-byte numbers that are given as lists of bytes.'''
    products = []
    for i in xrange(len(a)):
        for j in xrange(len(b)):
            product = a[i] * b[j]
            for k in xrange(i + j):
                product = product << 8
            products.append(product)

    return sum(products)

a = [0x01, 0x02]
b = [0x01, 0x03]
print mul(a, b)
