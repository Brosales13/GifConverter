//
//  GifCell.swift
//  GifConverter
//
//  Created by Rosales,Brian on 9/18/25.
//

import SwiftUI

struct GifCell: View {
    let image: Image?
    let title: String
    let duration: Int
    
    var body: some View {
        HStack {
            if let image {
                image
                    .frame(width: 60, height: 60)
                    .card(borderColor: .primary, cornerRadius: 8)
            } else {
                Text("No Image Found")
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: 60, height: 60)
                    .padding(2)
                    .background(.black)
                    .card(borderColor: .primary, cornerRadius: 8)
            }
            
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                
                Text("\(duration)")
                    .font(.body)
            }
        }
    }
}

#Preview {
    GifCell(image: nil, title: "topgun-test", duration: 11)
}
