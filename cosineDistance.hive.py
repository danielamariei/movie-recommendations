#!/usr/bin/env python

import sys
import math

def main():
	for line in sys.stdin:
		trimmed = line.strip()
      	fields = trimmed.split('\t')

		A = fields[0]
		B = fields[1]
		print cosineDistance(A, B)

def cosineDistance(firstBag, secondBag):
	A = extractRatingsDict(firstBag)
	B = extractRatingsDict(secondBag)
	return computeCosineDistance(A, B)


def extractRatingsDict(bag):
	D = {}
	for entry in bag:
		fields = entry.split('\t')
		movieId = int(fields[0])
		rating = float(fields[1])
		D[movieId] = rating

	return D


def computeCosineDistance(A, B):
	dotProd = computeDotProduct(A, B)
	a = sqrtOfSumSquaredElements(A.values())
	b = sqrtOfSumSquaredElements(B.values())
	
	try:
		return dotProd / (a * b)
	except ZeroDivisionError:
		return 0.001


def computeDotProduct(A, B):
	dotProduct = 0.0
	for key in A:
		if key in B:
			dotProduct += (A[key] * B[key])

	return dotProduct


def sqrtOfSumSquaredElements(V):
	s = sum([e*e for e in V])
	return math.sqrt(s)


if __name__ == '__main__':
  main()
