
grad.desc = function(
  FUN = function(x, y) x^2 + 2 * y^2, rg = c(-3, -3, 3, 3), init = c(-3, 3),
  gamma = 0.05, tol = 0.001, gr = NULL, len = 50, nmax = 50) {
  x <- seq(rg[1], rg[3], length = len)
  y <- seq(rg[2], rg[4], length = len)
  contour <- expand.grid(x = x, y = y)
  contour$z <- as.vector(outer(x, y, FUN))
  
  nms = names(formals(FUN))
  grad = if (is.null(gr)) {
    deriv(as.expression(body(FUN)), nms, function.arg = TRUE)
  } else {
    function(...) {
      res = FUN(...)
      attr(res, 'gradient') = matrix(gr(...), nrow = 1, ncol = 2)
      res
    }
  }
  
  xy <- init
  newxy <- xy - gamma * attr(grad(xy[1], xy[2]), 'gradient')
  z <- FUN(newxy[1], newxy[2])
  gap <- abs(z - FUN(xy[1], xy[2]))
  i <- 1
  while (gap > tol && i <= nmax) {
    xy <- rbind(xy, newxy[i, ])
    newxy <- rbind(newxy, xy[i + 1, ] - gamma * attr(grad(xy[i + 1, 1], xy[i + 1, 2]), 'gradient'))
    z <- c(z, FUN(newxy[i + 1, 1], newxy[i + 1, 2]))
    gap <- abs(z[i + 1] - FUN(xy[i + 1, 1], xy[i + 1, 2]))
    i <- i + 1
    if (i > nmax) warning('Maximum number of iterations reached!')
  }
  objective <- data.frame(iteration = 1:i, x = xy[, 1], y = xy[, 2], 
                          newx = newxy[, 1], newy = newxy[, 2], z = z)
  invisible(
    list(contour = contour, objective = objective)
  )
}

dat <- grad.desc()
contour <- dat$contour
objective <- dat$objective

library(plyr)
objective <- ldply(objective$iteration, function(i) {
  df <- subset(objective, iteration <= i)
  cbind(df, iteration2 = i)
})
objective2 <- subset(objective, iteration == iteration2)

library(animint2)
library(grid)

(contour.plot <- ggplot() + 
    geom_contour(data = contour, aes(x = x, y = y, z = z, colour = ..level..), size = .5) + 
    scale_colour_continuous(name = "z value") + 
    geom_path(data = objective, aes(x = x, y = y), showSelected = objective$iteration2, 
              colour = "red", size = 1, arrow = arrow(length = unit(.5, "cm"))) + 
    # argument arrow doesn't take effect.
    geom_point(data = objective, aes(x = x, y = y), showSelected = objective$iteration2, colour = "green", 
               size = 2) + 
    geom_text(data = objective2, aes(x = x, y = y - 0.2, label = round(z, 2)), showSelected = objective2$iteration2, 
              vjust = 1) + 
    # argument vjust or hjust doesn't take effect.
    scale_x_continuous(expand = c(0, 0)) + 
    scale_y_continuous(expand = c(0, 0)) + 
    ggtitle("contour of function value") + 
    theme_animint(width = 600, height = 600))

(objective.plot <- ggplot() +
    geom_line(data = objective2, aes(x = iteration, y = z), colour = "red") + 
    geom_point(data = objective2, aes(x = iteration, y = z), colour = "red") + 
    geom_tallrect(data = objective2, aes(xmin = iteration - 1 / 2, xmax = iteration + 1 / 2), 
                  clickSelects.variable = objective2$iteration2, alpha = .3) + 
    geom_text(data = objective2, aes(x = iteration, y = z + 0.3, 
                                     label = iteration), showSelected = objective2$iteration2) + 
    ggtitle("objective value vs. iteration") + 
    theme_animint(width = 600, height = 600))

viz <- list(contour = contour.plot, objective = objective.plot, 
            time = list(variable = "iteration2", ms = 2000), 
            title = "Demonstration of Gradient Descent Algorithm")
animint2dir(viz, out.dir = "grad.desc")
animint2gist(viz, out.dir = "grad.desc")

# Error in checkPlotForAnimintExtensions(p, list.name) : 
#   data does not have interactive variables

