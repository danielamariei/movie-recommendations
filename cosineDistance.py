import math

@outputSchema("cosineDist:float")
def cosineDistance(firstBag, secondBag):
	A = extractRatingsDict(firstBag)
	B = extractRatingsDict(secondBag)
	return computeCosineDistance(A, B)


def extractRatingsDict(bag):
	return dict((movieId, rating) for (userId, movieId, rating) in bag)


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
