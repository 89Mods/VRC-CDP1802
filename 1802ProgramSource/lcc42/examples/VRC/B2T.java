import java.lang.*;
import java.util.*;
import java.io.*;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

public class B2T {
	public static void main(String[] args) {
		try {
			if(args.length == 0) {
				System.err.println("No input file specified.");
				System.exit(1);
			}
			File f = new File(args[0]);
			if(f.length() > 65536) {
				System.err.println("Input file too large. Max is 64K.");
				System.exit(1);
			}
			FileInputStream fis = new FileInputStream(f);
			BufferedImage img = new BufferedImage(256, 256, BufferedImage.TYPE_INT_RGB);
			for(int i = 0; i < f.length(); i++) {
				int idxx = i & 255;
				int idxy = 255 - (i / 256);
				img.setRGB(idxx, idxy, (fis.read() & 0xFF) << 16);
			}
			fis.close();
			ImageIO.write(img, "png", new File("program.png"));
		}catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
