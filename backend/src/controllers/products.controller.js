const prisma = require('../config/prisma');

exports.getAllProducts = async (req, res, next) => {
  try {
    const products = await prisma.products.findMany({
      orderBy: { id: 'asc' }
    });
    res.json(products);
  } catch (error) {
    next(error);
  }
};
