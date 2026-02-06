import SwiftUI

struct CartView: View {
    @State private var cartItems: [CartItem] = CartItem.sampleItems
    
    var subtotal: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Cart")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("\(cartItems.count) items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                if cartItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Your cart is empty")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Browse products and add items to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(cartItems) { item in
                                CartItemCard(item: item) {
                                    withAnimation { cartItems.removeAll { $0.id == item.id } }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 180)
                    }
                }
            }
            
            // MARK: - Bottom Checkout Bar
            if !cartItems.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("Subtotal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(subtotal, specifier: "%.2f")")
                            .font(.title2.bold())
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "bag.fill")
                            Text("Checkout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Cart Item Card
struct CartItemCard: View {
    let item: CartItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .background(Color(.systemGray6))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    Text("\(item.quantity)")
                        .font(.subheadline.bold())
                        .frame(width: 24)
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

// MARK: - Cart Item Model
struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let imageName: String
    var quantity: Int
    
    static let sampleItems: [CartItem] = [
        CartItem(name: "Fanbyn Chair", price: 76.90, imageName: "chair", quantity: 1),
        CartItem(name: "Sofastar Sofa", price: 119.00, imageName: "sofa", quantity: 1),
        CartItem(name: "DreamBed", price: 299.00, imageName: "bed", quantity: 1)
    ]
}

#Preview {
    CartView()
}
