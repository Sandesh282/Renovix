import SwiftUI

struct ProductCard: View {
    let product: Product
    var onCartTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground)
    }
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    var priceColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .frame(width: 180, height: 260)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)

            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(product.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .offset(y: -40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
                        .zIndex(1)

                    if product.isNew {
                        Text("NEW")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .offset(x: -8, y: -20)
                            .zIndex(2)
                    }
                }
                .frame(height: 100) 

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85) 

                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(priceColor)
                        .minimumScaleFactor(0.9)

                    Spacer()

                    HStack {
                        Spacer()
                        Button(action: onCartTapped) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .padding(10)
                                .background(colorScheme == .dark ? Color.white : Color.black)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 180, height: 260)
        }
        .frame(width: 180, height: 260)
        .padding(.top, 40) 
    }
}


#Preview {
    ProductCard(product: Product(
        name: "Swivel Chair",
        description: "Modern and comfy",
        price: 109,
        imageName: "chair",
        isNew: true,
        isFavourite: false,
        category: .chairs,
        colorOptions: [.gray, .brown, .black, .yellow, .blue],
        variantImageNames: ["chair", "chair_variant1", "chair_variant2", "chair_variant3"],
        model3DName: "chair"
    )) {
        //Cart action
    }
}

